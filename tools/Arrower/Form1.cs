namespace Arrower
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
            pictureBox2.Image = new Bitmap(256, 128);
            pictureBox3.Image = new Bitmap(256, 128);
        }

        private void button1_Click(object sender, EventArgs e)
        {
            float step = 90f / 32;
            Graphics g = Graphics.FromImage(pictureBox2.Image);
            g.Clear(Color.White);
            for (int i = 0; i < 128; i++)
            {
                float angle = step * i;
                int posx = i % 16;
                int posy = i / 16;
                g.DrawImage(RotateImage((Bitmap)pictureBox1.Image, angle+90), new RectangleF(posx * 16, posy * 16, 15, 15), new RectangleF(0, 0, pictureBox1.Image.Width, pictureBox1.Image.Height), GraphicsUnit.Pixel);
            }
            pictureBox2.Refresh();
        }

        private Bitmap RotateImage(Bitmap bmp, float angle)
        {
            Bitmap rotatedImage = new Bitmap(bmp.Width, bmp.Height);
            rotatedImage.SetResolution(bmp.HorizontalResolution, bmp.VerticalResolution);

            using (Graphics g = Graphics.FromImage(rotatedImage))
            {
                // Set the rotation point to the center in the matrix
                g.TranslateTransform(bmp.Width / 2, bmp.Height / 2);
                // Rotate
                g.RotateTransform(angle);
                // Restore rotation point in the matrix
                g.TranslateTransform(-bmp.Width / 2, -bmp.Height / 2);
                // Draw the image on the bitmap
                g.DrawImage(bmp, new Point(0, 0));
            }

            return rotatedImage;
        }

        private void trackBar1_Scroll(object sender, EventArgs e)
        {
            float angle = (90f / 64) * trackBar1.Value;
            button1.Text = angle.ToString();
            Graphics g = Graphics.FromImage(pictureBox2.Image);
            g.Clear(Color.Red);
            g.DrawImage(RotateImage((Bitmap)pictureBox1.Image, angle), new RectangleF(0, 0, 15, 15), new RectangleF(0, 0, pictureBox1.Image.Width, pictureBox1.Image.Height), GraphicsUnit.Pixel);
            pictureBox2.Refresh();
        }

        private void button2_Click(object sender, EventArgs e)
        {
            if (saveFileDialog1.ShowDialog() == DialogResult.OK)
            {
                pictureBox2.Image.Save(saveFileDialog1.FileName);
            }
        }

        private void button3_Click(object sender, EventArgs e)
        {
            if (openFileDialog1.ShowDialog() == DialogResult.OK)
            {
                pictureBox1.Load(openFileDialog1.FileName);
            }
        }

        private void button5_Click(object sender, EventArgs e)
        {
            if (saveFileDialog1.ShowDialog() == DialogResult.OK)
            {
                pictureBox3.Image.Save(saveFileDialog1.FileName);
            }
        }

        private void button4_Click(object sender, EventArgs e)
        {
            Graphics g = Graphics.FromImage(pictureBox3.Image);
            g.Clear(Color.White);
            Bitmap src = (Bitmap)pictureBox2.Image;
            Bitmap dst = (Bitmap)pictureBox3.Image;
            int index = 0;
            for (int y = 0; y < 8; y++)
                for (int x = 0; x < 16; x++)
                    for (int y16 = 0; y16 < 16; y16++)
                        for (int x16 = 0; x16 < 16; x16++)
                        {
                            Color pixel = src.GetPixel(x * 16 + x16, y * 16 + y16);
                            dst.SetPixel(index % 256, index / 256, pixel);
                            index++;
                        }
            
            pictureBox3.Refresh();
        }
    }
}